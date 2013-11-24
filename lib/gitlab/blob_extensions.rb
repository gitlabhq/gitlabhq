require 'csv'

class Gitlab::Git::Blob
  
  def csv?
    text? && extname.downcase == '.csv' && to_csv
  end

  def to_csv(options = {})
    @csv ||= begin
      CSV.parse(data, options)
    rescue CSV::MalformedCSVError
      nil
    end
  end
  
end
