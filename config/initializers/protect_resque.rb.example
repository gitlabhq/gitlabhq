require 'resque/server'
Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user == "gitlab"
  password == "5iveL!fe"
end
