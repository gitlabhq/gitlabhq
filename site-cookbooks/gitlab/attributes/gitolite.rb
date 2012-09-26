#
# Cookbook Name:: gitlab
# Attributes:: gitolite
#
# Copyright 2010, RailsAnt, Inc.
# Copyright 2012, Gerald L. Hevener
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default['gitlab']['gitolite_url'] = "git://github.com/sitaramc/gitolite.git"
default['gitlab']['git_user'] = "git"
default['gitlab']['git_group'] = "git"

# Set git home directory
default['gitlab']['git_home'] = "/var/git"

# Set gitolite home directory
default['gitlab']['gitolite_home'] = "#{node['gitlab']['git_home']}/gitolite"

# Set gitolite umask
default['gitlab']['gitolite_umask'] = "0007"
