# Set attributes for the git user
default['gitlab']['user'] = "vagrant"
default['gitlab']['group'] = "vagrant"
default['gitlab']['home'] = "/home/vagrant"
default['gitlab']['app_home'] = "/vagrant"

# Set github URL for gitlab
default['gitlab']['gitlab_url'] = "git://github.com/gitlabhq/gitlabhq.git"
default['gitlab']['gitlab_branch'] = "master"

default['gitlab']['packages'] = %w{
  vim curl wget checkinstall libxslt-dev
  libcurl4-openssl-dev libssl-dev libmysql++-dev
  libicu-dev libc6-dev libyaml-dev nginx python python-dev libqt4-dev xvfb
  xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
}

default['gitlab']['trust_local_sshkeys'] = "yes"
default['gitlab']['https'] = false
default['gitlab']['ssl_certificate'] = "/etc/nginx/#{node['fqdn']}.crt"
default['gitlab']['ssl_certificate_key'] = "/etc/nginx/#{node['fqdn']}.key"
default['gitlab']['ssl_req'] = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/CN=#{node['fqdn']}/emailAddress=root@localhost"
