require 'factory_girl_rails'

(AbuseReport.default_per_page + 3).times do
  FactoryGirl.create(:abuse_report)
end
