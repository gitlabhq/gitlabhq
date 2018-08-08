namespace :gitlab do
  namespace :quick_actions do
    namespace :base do
      task :before do
        unless Rails.env.development?
          raise 'Quick actions are allowed in only development purpose'
        end
      end
    end
  end
end
