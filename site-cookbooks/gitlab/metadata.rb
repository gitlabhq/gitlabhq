long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
%w{ gitolite }.each do |cb_conflict|
  conflicts cb_conflict
end
%w{ git redisio build-essential python readline openssl perl xml zlib}.each do |cb_depend|
  depends cb_depend
end
%w{ debian ubuntu }.each do |os|
  supports os
end
