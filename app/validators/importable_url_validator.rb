# ImportableUrlValidator
#
# This validator blocks projects from using dangerous import_urls to help
# protect against Server-side Request Forgery (SSRF).
class ImportableUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    Gitlab::UrlBlocker.validate!(value, valid_ports: Project::VALID_IMPORT_PORTS)
  rescue Gitlab::UrlBlocker::BlockedUrlError => e
    record.errors.add(attribute, "is blocked: #{e.message}")
  end
end
