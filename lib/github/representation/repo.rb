module Github
  module Representation
    class Repo < Representation::Base
      def id
        raw['id']
      end
    end
  end
end
