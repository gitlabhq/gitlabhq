module Gitlab
  module Git
    BLANK_SHA = '0' * 40

    def self.extract_ref_name(ref)
      ref.gsub(/\Arefs\/(tags|heads)\//, '')
    end
  end
end
