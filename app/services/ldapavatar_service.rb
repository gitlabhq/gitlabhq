require 'rmagick'

class LDAPAvatarService
  def lookup_user_avatar_in_ldap()
    unless File.exist?(provider_options['local_avatar_storage_path'])
      Rails.logger.warn("LDAP avatar directory path, #{provider_options['local_avatar_storage_path']}, does not exist")
      return false
    end

    img_blob = nil
    path     = File.join(provider_options['local_avatar_storage_path'], "#{@email_hash}_#{@img_size}.jpg")
    ldap     = Net::LDAP.new(provider_adapter_options)
    filter   = Net::LDAP::Filter.eq('mail', @user_email)
    attrs    = %w(thumbnailphoto)
    results  = ldap.search(:base => provider_options['base'], :filter => filter, :attributes => attrs)

    if results.nil?
      response = ldap.get_operation_result
      unless response.code.zero?
        Rails.logger.warn("LDAP search error in avatar lookup: #{response.message}")
      end
    else
      results.select { |result| result.attribute_names.include?(:thumbnailphoto) }.each do |entry|
        img_blob = entry.thumbnailphoto.first
      end
    end

    unless img_blob.nil?
      begin
        img = Magick::Image.from_blob(img_blob).first
        img.crop_resized! @img_size, @img_size, Magick::CenterGravity unless img.columns == @img_size
        img_blob = img.to_blob { self.format = 'jpeg' }
      rescue => e
        Rails.logger.warn("Failed to resize ldap avatar to #{@img_size}x#{@img_size}. #{e.message}")
      end
    end

    File.open(path, 'wb') { |f| f.write(img_blob) }.nonzero?
  end
end

