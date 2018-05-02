# Frontend Development Guidelines

This document describes various guidelines to ensure consistency and quality
across GitLab's frontend team.

## Overview

GitLab is built on top of [Ruby on Rails][rails] using [Haml][haml] and also a JavaScript based Frontend with [Vue.js][vue].
Be wary of [the limitations that come with using Hamlit][hamlit-limits]. We also use [SCSS][scss] and plain JavaScript with
modern ECMAScript standards supported through [Babel][babel] and ES module support through [webpack][webpack].

### Javascript development

[Vue.js][vue] is used for particularly advanced, dynamic elements and based on previous iterations [jQuery][jquery] is used in lot of places through the application's JavaScript.

We also use [Axios][axios] to handle all of our network requests.

We also utilize [webpack][webpack] to handle the bundling, minification, and
compression of our assets.

Working with our frontend assets requires Node (v6.0 or greater) and Yarn
(v1.2 or greater).  You can find information on how to install these on our
[installation guide][install].

### Browser Support

For our currently-supported browsers, see our [requirements][requirements].

---

## [Development Process](development_process.md)
How we plan and execute the work on the frontend.

## [Architecture](architecture.md)
How we go about making fundamental design decisions in GitLab's frontend team
or make changes to our frontend development guidelines.

## [Testing](../testing_guide/frontend_testing.md)
How we write frontend tests, run the GitLab test suite, and debug test related
issues.

## [Design Patterns](design_patterns.md)
Common JavaScript design patterns in GitLab's codebase.

## [Vue.js Best Practices](vue.md)
Vue specific design patterns and practices.

## [Axios](axios.md)
Axios specific practices and gotchas.

## [Icons](icons.md)
How we use SVG for our Icons.

## [Components](components.md)

How we use UI components.

---

## Style Guides

### [JavaScript Style Guide](style_guide_js.md)

We use eslint to enforce our JavaScript style guides.  Our guide is based on
the excellent [Airbnb][airbnb-js-style-guide] style guide with a few small
changes.

### [SCSS Style Guide](style_guide_scss.md)

Our SCSS conventions which are enforced through [scss-lint][scss-lint].

---

## [Performance](performance.md)
Best practices for monitoring and maximizing frontend performance.

---

## [Security](security.md)
Frontend security practices.

---

## [Accessibility](accessibility.md)
Our accessibility standards and resources.

## [Internationalization (i18n) and Translations](../i18n/externalization.md)
Frontend internationalization support is described in [this document](../i18n/).
The [externalization part of the guide](../i18n/externalization.md) explains the helpers/methods available.


[rails]: http://rubyonrails.org/
[haml]: http://haml.info/
[hamlit]: https://github.com/k0kubun/hamlit
[hamlit-limits]: https://github.com/k0kubun/hamlit/blob/master/REFERENCE.md#limitations
[scss]: http://sass-lang.com/
[babel]: https://babeljs.io/
[webpack]: https://webpack.js.org/
[jquery]: https://jquery.com/
[vue]: http://vuejs.org/
[axios]: https://github.com/axios/axios
[airbnb-js-style-guide]: https://github.com/airbnb/javascript
[scss-lint]: https://github.com/brigade/scss-lint
[install]: ../../install/installation.md#4-node
[requirements]: ../../install/requirements.md#supported-web-browsers

---

## [DropLab](droplab/droplab.md)
Our internal `DropLab` dropdown library.

* [DropLab](droplab/droplab.md)
* [Ajax plugin](droplab/plugins/ajax.md)
* [Filter plugin](droplab/plugins/filter.md)
* [InputSetter plugin](droplab/plugins/input_setter.md)
