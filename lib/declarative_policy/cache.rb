module DeclarativePolicy
  module Cache
    class << self
      def user_key(user)
        return '<anonymous>' if user.nil?

        id_for(user)
      end

      def policy_key(user, subject)
        u = user_key(user)
        s = subject_key(subject)
        "/dp/policy/#{u}/#{s}"
      end

      def subject_key(subject)
        return '<nil>' if subject.nil?
        return subject.inspect if subject.is_a?(Symbol)

        "#{subject.class.name}:#{id_for(subject)}"
      end

      private

      def id_for(obj)
        id =
          begin
            obj.id
          rescue NoMethodError
            nil
          end

        id || "##{obj.object_id}"
      end
    end
  end
end
