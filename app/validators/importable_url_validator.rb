# ImportableUrlValidator
#
# This validator blocks projects from using dangerous import_urls to help
# protect against Server-side Request Forgery (SSRF).
class ImportableUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if Gitlab::UrlBlocker.blocked_url?(value)
      record.errors.add(attribute, "imports are not allowed from that URL")
    end
  end
end
