# UniquenessOfInMemoryValidator
#
# This validtor is designed for especially the following condition
# - Use `accepts_nested_attributes_for :xxx` in a parent model
# - Use `validates :xxx, uniqueness: { scope: :xxx_id }` in a child model
#
# Inspired by https://stackoverflow.com/a/2883129/2522666
module ActiveRecord
  class Base
    # Validate that the the objects in +collection+ are unique
    # when compared against all their non-blank +attrs+. If not
    # add +message+ to the base errors.
    def validate_uniqueness_of_in_memory(collection, attrs, message)
      hashes = collection.inject({}) do |hash, record|
        key = attrs.map { |a| record.send(a).to_s }.join
        if key.blank? || record.marked_for_destruction?
          key = record.object_id
        end
        hash[key] = record unless hash[key]
        hash
      end

      if collection.length > hashes.length
        self.errors.add(*message)
      end
    end
  end
end

class UniquenessOfInMemoryValidator < ActiveModel::Validator
  def validate(record)
    record.validate_uniqueness_of_in_memory(
      record.public_send(options[:collection]),
      options[:attrs],
      options[:message])
  end
end
