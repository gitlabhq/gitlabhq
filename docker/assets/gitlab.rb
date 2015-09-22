# Docker options
## Prevent Postgres from trying to allocate 25% of total memory
postgresql['shared_buffers'] = '1MB'

## PIN users to UIDs
user['uid'] = 998
user['gid'] = 998
postgresql['uid'] = 996
postgresql['gid'] = 996
redis['uid'] = 997
redis['gid'] = 997
web_server['uid'] = 999
web_server['gid'] = 999
gitlab_ci['uid'] = 995
gitlab_ci['gid'] = 995

# Get hostname from shell
host = `hostname`.strip
external_url "http://#{host}"

# Load /etc/gitlab/gitlab.rb
from_file("/etc/gitlab/gitlab.rb")
