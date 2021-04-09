import { s__, __ } from '~/locale';

export const CANCEL_REQUEST = 'CANCEL_REQUEST';
export const LAYOUT_CHANGE_DELAY = 300;
export const FILTER_PIPELINES_SEARCH_DELAY = 200;
export const ANY_TRIGGER_AUTHOR = 'Any';
export const SUPPORTED_FILTER_PARAMETERS = ['username', 'ref', 'status'];
export const FILTER_TAG_IDENTIFIER = 'tag';
export const SCHEDULE_ORIGIN = 'schedule';

export const TestStatus = {
  FAILED: 'failed',
  SKIPPED: 'skipped',
  SUCCESS: 'success',
  ERROR: 'error',
  UNKNOWN: 'unknown',
};

export const FETCH_AUTHOR_ERROR_MESSAGE = __('There was a problem fetching project users.');
export const FETCH_BRANCH_ERROR_MESSAGE = __('There was a problem fetching project branches.');
export const FETCH_TAG_ERROR_MESSAGE = __('There was a problem fetching project tags.');
export const RAW_TEXT_WARNING = s__(
  'Pipeline|Raw text search is not currently supported. Please use the available search tokens.',
);

/* Error constants shared across graphs */
export const DEFAULT = 'default';
export const DELETE_FAILURE = 'delete_pipeline_failure';
export const DRAW_FAILURE = 'draw_failure';
export const EMPTY_PIPELINE_DATA = 'empty_data';
export const INVALID_CI_CONFIG = 'invalid_ci_config';
export const LOAD_FAILURE = 'load_failure';
export const PARSE_FAILURE = 'parse_failure';
export const POST_FAILURE = 'post_failure';
export const UNSUPPORTED_DATA = 'unsupported_data';

export const CHILD_VIEW = 'child';

// The keys of the templates are the same as their filenames
export const HELLO_WORLD_TEMPLATE_KEY = 'Hello-World';
export const SUGGESTED_CI_TEMPLATES = {
  Android: { logoPath: '/assets/illustrations/logos/android.svg' },
  Bash: { logoPath: '/assets/illustrations/logos/bash.svg' },
  'C++': { logoPath: '/assets/illustrations/logos/c_plus_plus.svg' },
  Clojure: { logoPath: '/assets/illustrations/logos/clojure.svg' },
  Composer: { logoPath: '/assets/illustrations/logos/composer.svg' },
  Crystal: { logoPath: '/assets/illustrations/logos/crystal.svg' },
  Dart: { logoPath: '/assets/illustrations/logos/dart.svg' },
  Django: { logoPath: '/assets/illustrations/logos/django.svg' },
  Docker: { logoPath: '/assets/illustrations/logos/docker.svg' },
  Elixir: { logoPath: '/assets/illustrations/logos/elixir.svg' },
  'iOS-Fastlane': { logoPath: '/assets/illustrations/logos/fastlane.svg' },
  Flutter: { logoPath: '/assets/illustrations/logos/flutter.svg' },
  Go: { logoPath: '/assets/illustrations/logos/go_logo.svg' },
  Gradle: { logoPath: '/assets/illustrations/logos/gradle.svg' },
  Grails: { logoPath: '/assets/illustrations/logos/grails.svg' },
  dotNET: { logoPath: '/assets/illustrations/logos/dotnet.svg' },
  Rails: { logoPath: '/assets/illustrations/logos/rails.svg' },
  Julia: { logoPath: '/assets/illustrations/logos/julia.svg' },
  Laravel: { logoPath: '/assets/illustrations/logos/laravel.svg' },
  Latex: { logoPath: '/assets/illustrations/logos/latex.svg' },
  Maven: { logoPath: '/assets/illustrations/logos/maven.svg' },
  Mono: { logoPath: '/assets/illustrations/logos/mono.svg' },
  Nodejs: { logoPath: '/assets/illustrations/logos/node_js.svg' },
  npm: { logoPath: '/assets/illustrations/logos/npm.svg' },
  OpenShift: { logoPath: '/assets/illustrations/logos/openshift.svg' },
  Packer: { logoPath: '/assets/illustrations/logos/packer.svg' },
  PHP: { logoPath: '/assets/illustrations/logos/php.svg' },
  Python: { logoPath: '/assets/illustrations/logos/python.svg' },
  Ruby: { logoPath: '/assets/illustrations/logos/ruby.svg' },
  Rust: { logoPath: '/assets/illustrations/logos/rust.svg' },
  Scala: { logoPath: '/assets/illustrations/logos/scala.svg' },
  Swift: { logoPath: '/assets/illustrations/logos/swift.svg' },
  Terraform: { logoPath: '/assets/illustrations/logos/terraform.svg' },
};
