# Activate below rake task in cron by issuing 'whenever -i'
every :saturday, :at => '11pm' do
  rake "git_gc"
end
