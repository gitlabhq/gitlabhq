# EmailValidator
#
# Based on https://github.com/balexand/email_validator
#
# Extended to use only strict mode with following allowed characters:
# ' - apostrophe
#
# See http://www.remote.org/jochen/mail/info/chars.html
#
class EmailValidator < ActiveModel::EachValidator
  PATTERN = /@/.freeze

  def validate_each(record, attribute, value)
    unless value =~ PATTERN
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end
end
