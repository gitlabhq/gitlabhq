# GitLab Grape OpenAPI

> [!warning]
> This gem is currently designed entirely for internal use at GitLab. This gem is not functional and not used in production.

Internal gem for generating OpenAPI 3.0 specifications from Grape API definitions.

## Usage with `gitlab-org/gitlab`

- With a running and configured GDK, start a `rails console` in a terminal.
- Use the script below to run the generator with _all_ APIs and entities in the monolith.

    ```ruby
       Rails.application.eager_load!
       api_classes = API::Base.descendants
       entity_classes = Grape::Entity.descendants
       spec = Gitlab::GrapeOpenapi.generate(api_classes: api_classes, entity_classes: entity_classes)
       File.write(Rails.root.join('tmp', 'myfile.json'), JSON.pretty_generate(spec))
    ```
  
- The OpenAPI 3.0 spec will be dumped in `tmp/myfile.json` in the `GDK_ROOT/gitlab` directory.
- Ensure `redocly-cli` is installed. `npm install @redocly/cli -g`
- To render the documentation in something viewable online, such as redocly, run `redocly build-docs ~/gdk/gitlab/tmp/myfile.json` and open the generated static site.

## Development

```bash
bundle install
bundle exec rspec
```
