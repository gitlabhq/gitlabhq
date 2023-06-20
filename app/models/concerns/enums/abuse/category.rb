# frozen_string_literal: true

module Enums
  module Abuse
    module Category
      def self.categories
        {
          spam: 0,  # spamcheck
          virus: 1, # VirusTotal
          fraud: 2, # Arkos, Telesign
          ci_cd: 3  # PVS
        }
      end
    end
  end
end
