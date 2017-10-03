# LdapFilteralidator
#
# Custom validator for LDAP filters
#
# Example:
#
#   class LdapGroupLink < ActiveRecord::Base
#     validates :filter, ldap_filter: true
#   end
#
class LdapFilterValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    Net::LDAP::Filter::FilterParser.parse(value)
  rescue Net::LDAP::FilterSyntaxInvalidError
    record.errors.add(attribute, 'must be a valid filter')
  end
end
