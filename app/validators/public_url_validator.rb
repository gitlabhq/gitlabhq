# PublicUrlValidator
#
# Custom validator for URLs. This validator works like UrlValidator but
# it blocks by default urls pointing to localhost or the local network.
#
# This validator accepts the same params UrlValidator does.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :personal_url, public_url: true
#
#     validates :ftp_url, public_url: { protocols: %w(ftp) }
#
#     validates :git_url, public_url: { allow_localhost: true, allow_local_network: true}
#   end
#
class PublicUrlValidator < UrlValidator
  private

  def default_options
    # By default block all urls pointing to localhost or the local network
    super.merge(allow_localhost: false,
                allow_local_network: false)
  end
end
