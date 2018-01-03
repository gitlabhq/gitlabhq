class KeyRestrictionValidator < ActiveModel::EachValidator
  FORBIDDEN = -1

  def self.supported_sizes(type)
    Gitlab::SSHPublicKey.supported_sizes(type)
  end

  def self.supported_key_restrictions(type)
    [0, *supported_sizes(type), FORBIDDEN]
  end

  def validate_each(record, attribute, value)
    unless valid_restriction?(value)
      record.errors.add(attribute, "must be forbidden, allowed, or one of these sizes: #{supported_sizes_message}")
    end
  end

  private

  def supported_sizes_message
    sizes = self.class.supported_sizes(options[:type])
    sizes.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
  end

  def valid_restriction?(value)
    choices = self.class.supported_key_restrictions(options[:type])
    choices.include?(value)
  end
end
