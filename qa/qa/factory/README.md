# Factory objects in GitLab QA

In GitLab QA we are using factories to create resources.

Factories implementation are primarily done using Browser UI steps, but can also
be done via the API.

## Why do we need that?

We need factory objects because we need to reduce duplication when creating
resources for our QA tests.

## How to properly implement a factory object?

All factories should inherit from [`Factory::Base`](./base.rb).

There is only one mandatory method to implement to define a factory. This is the
`#fabricate!` method, which is used to build a resource via the browser UI.
Note that you should only use [Page objects](../page/README.md) to interact with
a Web page in this method.

Here is an imaginary example:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        def initialize(name)
          @name = name
        end

        def fabricate!
          Page::Dashboard::Index.perform do |dashboard_index|
            dashboard_index.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end
      end
    end
  end
end
```

### Define API implementation

A factory may also implement the three following methods to be able to create a
resource via the public GitLab API:

- `#api_get_path`: The `GET` path to fetch an existing resource.
- `#api_post_path`: The `POST` path to create a new resource.
- `#api_post_body`: The `POST` body (as a Ruby hash) to create a new resource.

Let's take the `Shirt` factory example, and add these three API methods:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        def initialize(name)
          @name = name
        end

        def fabricate!
          Page::Dashboard::Index.perform do |dashboard_index|
            dashboard_index.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/shirt/#{name}"
        end

        def api_post_path
          "/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

The [`Project` factory](./resource/project.rb) is a good real example of Browser
UI and API implementations.

### Define dependencies

A resource may need an other resource to exist first. For instance, a project
needs a group to be created in.

To define a dependency, you can use the `dependency` DSL method.
The first argument is a factory class, then you should pass `as: <name>` to give
a name to the dependency.
That will allow access to the dependency from your resource object's methods.
You would usually use it in `#fabricate!`, `#api_get_path`, `#api_post_path`,
`#api_post_body`.

Let's take the `Shirt` factory, and add a `project` dependency to it:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-create-a-shirt'
        end

        def initialize(name)
          @name = name
        end

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/project/#{project.path}/shirt/#{name}"
        end

        def api_post_path
          "/project/#{project.path}/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

**Note that dependencies are always built via the API fabrication method if
supported by their factories.**

### Define attributes on the created resource

Once created, you may want to populate a resource with attributes that can be
found in the Web page, or in the API response.
For instance, once you create a project, you may want to store its repository
SSH URL as an attribute.

To define an attribute, you can use the `product` DSL method.
The first argument is the attribute name, then you should define a name for the
dependency to be accessible from your resource object's methods.

Let's take the `Shirt` factory, and define a `:brand` attribute:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-create-a-shirt'
        end

        # Attribute populated from the Browser UI (using the block)
        product :brand do
          Page::Shirt::Show.perform do |shirt_show|
            shirt_show.fetch_brand_from_page
          end
        end

        def initialize(name)
          @name = name
        end

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/project/#{project.path}/shirt/#{name}"
        end

        def api_post_path
          "/project/#{project.path}/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

#### Inherit a factory's attribute

Sometimes, you want a resource to inherit its factory attributes. For instance,
it could be useful to pass the `size` attribute from the `Shirt` factory to the
created resource.
You can do that by defining `product :attribute_name` without a block.

Let's take the `Shirt` factory, and define a `:name` and a `:size` attributes:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-create-a-shirt'
        end

        # Attribute from the Browser UI (using the block)
        product :brand do
          Page::Shirt::Show.perform do |shirt_show|
            shirt_show.fetch_brand_from_page
          end
        end

        # Attribute inherited from the Shirt factory if present,
        # or a QA::Factory::Product::NoValueError is raised otherwise
        product :name
        product :size

        def initialize(name)
          @name = name
        end

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/project/#{project.path}/shirt/#{name}"
        end

        def api_post_path
          "/project/#{project.path}/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

#### Define an attribute based on an API response

Sometimes, you want to define a resource attribute based on the API response
from its `GET` or `POST` request. For instance, if the creation of a shirt via
the API returns

```ruby
{
  brand: 'a-brand-new-brand',
  size: 'extra-small',
  style: 't-shirt',
  materials: [[:cotton, 80], [:polyamide, 20]]
}
```

you may want to store `style` as-is in the resource, and fetch the first value
of the first `materials` item in a `main_fabric` attribute.

For both attributes, you will need to define an inherited attribute, as shown
in "Inherit a factory's attribute" above, but in the case of `main_fabric`, you
will need to implement the
`#transform_api_resource` method to first populate the `:main_fabric` key in the
API response so that it can be used later to automatically populate the
attribute on your resource.

If an attribute can only be retrieved from the API response, you should define
a block to give it a default value, otherwise you could get a
`QA::Factory::Product::NoValueError` when creating your resource via the
Browser UI.

Let's take the `Shirt` factory, and define a `:style` and a `:main_fabric`
attributes:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name, :size

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-create-a-shirt'
        end

        # Attribute fetched from the API response if present,
        # or from the Browser UI otherwise (using the block)
        product :brand do
          Page::Shirt::Show.perform do |shirt_show|
            shirt_show.fetch_brand_from_page
          end
        end

        # Attribute fetched from the API response if present,
        # or from the Shirt factory if present,
        # or a QA::Factory::Product::NoValueError is raised otherwise
        product :name
        product :size
        product :style do
          'unknown'
        end
        product :main_fabric do
          'unknown'
        end

        def initialize(name)
          @name = name
        end

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/project/#{project.path}/shirt/#{name}"
        end

        def api_post_path
          "/project/#{project.path}/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end

        private

        def transform_api_resource(api_response)
          api_response[:main_fabric] = api_response[:materials][0][0]
          api_response
        end
      end
    end
  end
end
```

**Notes on attributes precedence:**

- attributes from the API response take precedence over attributes from the
  Browser UI
- attributes from the Browser UI take precedence over attributes from the
  factory (i.e inherited)
- attributes without a value will raise a `QA::Factory::Product::NoValueError` error

## Creating resources in your tests

To create a resource in your tests, you can call the `.fabricate!` method on the
factory class.
Note that if the factory supports API fabrication, this will use this
fabrication by default.

Here is an example that will use the API fabrication method under the hood since
it's supported by the `Shirt` factory:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate!('my-shirt') do |shirt|
  shirt.size = 'small'
end

expect(page).to have_text(my_shirt.brand) # => "a-brand-new-brand" from the API response
expect(page).to have_text(my_shirt.name) # => "my-shirt" from the inherited factory's attribute
expect(page).to have_text(my_shirt.size) # => "extra-small" from the API response
expect(page).to have_text(my_shirt.style) # => "t-shirt" from the API response
expect(page).to have_text(my_shirt.main_fabric) # => "cotton" from the (transformed) API response
```

If you explicitely want to use the Browser UI fabrication method, you can call
the `.fabricate_via_browser_ui!` method instead:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate_via_browser_ui!('my-shirt') do |shirt|
  shirt.size = 'small'
end

expect(page).to have_text(my_shirt.brand) # => the brand name fetched from the `Page::Shirt::Show` page
expect(page).to have_text(my_shirt.name) # => "my-shirt" from the inherited factory's attribute
expect(page).to have_text(my_shirt.size) # => "small" from the inherited factory's attribute
expect(page).to have_text(my_shirt.style) # => "unknown" from the attribute block
expect(page).to have_text(my_shirt.main_fabric) # => "unknown" from the attribute block
```

You can also explicitely use the API fabrication method, by calling the
`.fabricate_via_api!` method:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate_via_api!('my-shirt') do |shirt|
  shirt.size = 'small'
end
```

In this case, the result will be similar to calling `Factory::Resource::Shirt.fabricate!('my-shirt')`.

## Where to ask for help?

If you need more information, ask for help on `#quality` channel on Slack
(internal, GitLab Team only).

If you are not a Team Member, and you still need help to contribute, please
open an issue in GitLab CE issue tracker with the `~QA` label.
