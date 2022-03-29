import Ajv from 'ajv';
import AjvFormats from 'ajv-formats';
import CiSchema from '~/editor/schema/ci.json';

// JSON POSITIVE TESTS
import AllowFailureJson from './json_tests/positive_tests/allow_failure.json';
import EnvironmentJson from './json_tests/positive_tests/environment.json';
import GitlabCiDependenciesJson from './json_tests/positive_tests/gitlab-ci-dependencies.json';
import GitlabCiJson from './json_tests/positive_tests/gitlab-ci.json';
import InheritJson from './json_tests/positive_tests/inherit.json';
import MultipleCachesJson from './json_tests/positive_tests/multiple-caches.json';
import RetryJson from './json_tests/positive_tests/retry.json';
import TerraformReportJson from './json_tests/positive_tests/terraform_report.json';
import VariablesMixStringAndUserInputJson from './json_tests/positive_tests/variables_mix_string_and_user_input.json';
import VariablesJson from './json_tests/positive_tests/variables.json';

// JSON NEGATIVE TESTS
import DefaultNoAdditionalPropertiesJson from './json_tests/negative_tests/default_no_additional_properties.json';
import InheritDefaultNoAdditionalPropertiesJson from './json_tests/negative_tests/inherit_default_no_additional_properties.json';
import JobVariablesMustNotContainObjectsJson from './json_tests/negative_tests/job_variables_must_not_contain_objects.json';
import ReleaseAssetsLinksEmptyJson from './json_tests/negative_tests/release_assets_links_empty.json';
import ReleaseAssetsLinksInvalidLinkTypeJson from './json_tests/negative_tests/release_assets_links_invalid_link_type.json';
import ReleaseAssetsLinksMissingJson from './json_tests/negative_tests/release_assets_links_missing.json';
import RetryUnknownWhenJson from './json_tests/negative_tests/retry_unknown_when.json';

// YAML POSITIVE TEST
import CacheYaml from './yaml_tests/positive_tests/cache.yml';
import FilterYaml from './yaml_tests/positive_tests/filter.yml';
import IncludeYaml from './yaml_tests/positive_tests/include.yml';
import RulesYaml from './yaml_tests/positive_tests/rules.yml';

// YAML NEGATIVE TEST
import CacheNegativeYaml from './yaml_tests/negative_tests/cache.yml';
import IncludeNegativeYaml from './yaml_tests/negative_tests/include.yml';

const ajv = new Ajv({
  strictTypes: false,
  strictTuples: false,
  allowMatchingProperties: true,
});

AjvFormats(ajv);
const schema = ajv.compile(CiSchema);

describe('positive tests', () => {
  it.each(
    Object.entries({
      // JSON
      AllowFailureJson,
      EnvironmentJson,
      GitlabCiDependenciesJson,
      GitlabCiJson,
      InheritJson,
      MultipleCachesJson,
      RetryJson,
      TerraformReportJson,
      VariablesMixStringAndUserInputJson,
      VariablesJson,

      // YAML
      CacheYaml,
      FilterYaml,
      IncludeYaml,
      RulesYaml,
    }),
  )('schema validates %s', (_, input) => {
    expect(input).toValidateJsonSchema(schema);
  });
});

describe('negative tests', () => {
  it.each(
    Object.entries({
      // JSON
      DefaultNoAdditionalPropertiesJson,
      JobVariablesMustNotContainObjectsJson,
      InheritDefaultNoAdditionalPropertiesJson,
      ReleaseAssetsLinksEmptyJson,
      ReleaseAssetsLinksInvalidLinkTypeJson,
      ReleaseAssetsLinksMissingJson,
      RetryUnknownWhenJson,

      // YAML
      CacheNegativeYaml,
      IncludeNegativeYaml,
    }),
  )('schema validates %s', (_, input) => {
    expect(input).not.toValidateJsonSchema(schema);
  });
});
