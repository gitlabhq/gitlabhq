---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ruby gems API

This is the API documentation for [Ruby gems](../../user/packages/rubygems_registry/index.md).

WARNING:
This API is used by the [Ruby gems and Bundler package manager clients](https://maven.apache.org/)
and is generally not meant for manual consumption. This API is under development and is not ready
for production use due to limited functionality.

For instructions on how to upload and install gems from the GitLab
package registry, see the [Ruby gems registry documentation](../../user/packages/rubygems_registry/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [Ruby gems registry documentation](../../user/packages/rubygems_registry/index.md)
for details on which headers and token types are supported.

## Enable the Ruby gems API

The Ruby gems API for GitLab is behind a feature flag that is disabled by default. GitLab
administrators with access to the GitLab Rails console can enable this API for your instance.

To enable it:

```ruby
Feature.enable(:rubygem_packages)
```

To disable it:

```ruby
Feature.disable(:rubygem_packages)
```

To enable or disable it for specific projects:

```ruby
Feature.enable(:rubygem_packages, Project.find(1))
Feature.disable(:rubygem_packages, Project.find(2))
```

## Download a gem file

> Introduced in GitLab 13.10.

Download a gem:

```plaintext
GET projects/:id/packages/rubygems/gems/:file_name
```

| Attribute    | Type   | Required | Description |
| ------------ | ------ | -------- | ----------- |
| `id`         | string | yes      | The ID or full path of the project. |
| `file_name`  | string | yes      | The name of the `.gem` file. |

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem"
```

Write the output to file:

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem" >> my_gem-1.0.0.gem
```

This writes the downloaded file to `my_gem-1.0.0.gem` in the current directory.

## Fetch a list of dependencies

> Introduced in GitLab 13.10.

Fetch a list of dependencies for a list of gems:

```plaintext
GET projects/:id/packages/rubygems/api/v1/dependencies
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the project. |
| `gems`    | string | no       | Comma-separated list of gems to fetch dependencies for. |

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,foo"
```

This endpoint returns a marshalled array of hashes for all versions of the requested gems. Since the
response is marshalled, you can store it in a file. If Ruby is installed, you can use the following
Ruby command to read the response. For this to work, you must
[set your credentials in `~/.gem/credentials`](../../user/packages/rubygems_registry/index.md#authenticate-with-a-personal-access-token-or-deploy-token):

```shell
$ ruby -ropen-uri -rpp -e \
  'pp Marshal.load(open("https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,rails,foo"))'

[{:name=>"my_gem", :number=>"0.0.1", :platform=>"ruby", :dependencies=>[]},
 {:name=>"my_gem",
  :number=>"0.0.3",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"my_gem",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"foo",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
    ["dependency_2", "= 3.0.0"],
    ["dependency_4", ">= 0"]]}]
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Upload a gem

> Introduced in GitLab 13.11.

Upload a gem:

```plaintext
POST projects/:id/packages/rubygems/api/v1/gems
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the project. |

```shell
curl --request POST \
     --upload-file path/to/my_gem_file.gem \
     --header "Authorization:<personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/gems"
```
