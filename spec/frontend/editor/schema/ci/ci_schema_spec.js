import Ajv from 'ajv';
import AjvFormats from 'ajv-formats';
import CiSchema from '~/editor/schema/ci.json';

// JSON POSITIVE TESTS (LEGACY)
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

// JSON NEGATIVE TESTS (LEGACY)
import DefaultNoAdditionalPropertiesJson from './json_tests/negative_tests/default_no_additional_properties.json';
import InheritDefaultNoAdditionalPropertiesJson from './json_tests/negative_tests/inherit_default_no_additional_properties.json';
import JobVariablesMustNotContainObjectsJson from './json_tests/negative_tests/job_variables_must_not_contain_objects.json';
import ReleaseAssetsLinksJson from './json_tests/negative_tests/release_assets_links.json';
import RetryUnknownWhenJson from './json_tests/negative_tests/retry_unknown_when.json';

// YAML POSITIVE TEST
import ArtifactsYaml from './yaml_tests/positive_tests/artifacts.yml';
import CacheYaml from './yaml_tests/positive_tests/cache.yml';
import FilterYaml from './yaml_tests/positive_tests/filter.yml';
import IncludeYaml from './yaml_tests/positive_tests/include.yml';
import RulesYaml from './yaml_tests/positive_tests/rules.yml';
import RulesNeedsYaml from './yaml_tests/positive_tests/rules_needs.yml';
import ProjectPathYaml from './yaml_tests/positive_tests/project_path.yml';
import VariablesYaml from './yaml_tests/positive_tests/variables.yml';
import JobWhenYaml from './yaml_tests/positive_tests/job_when.yml';
import IdTokensYaml from './yaml_tests/positive_tests/id_tokens.yml';
import HooksYaml from './yaml_tests/positive_tests/hooks.yml';
import SecretsYaml from './yaml_tests/positive_tests/secrets.yml';
import ServicesYaml from './yaml_tests/positive_tests/services.yml';

// YAML NEGATIVE TEST
import ArtifactsNegativeYaml from './yaml_tests/negative_tests/artifacts.yml';
import CacheKeyNeative from './yaml_tests/negative_tests/cache.yml';
import IncludeNegativeYaml from './yaml_tests/negative_tests/include.yml';
import JobWhenNegativeYaml from './yaml_tests/negative_tests/job_when.yml';
import ProjectPathIncludeEmptyYaml from './yaml_tests/negative_tests/project_path/include/empty.yml';
import ProjectPathIncludeInvalidVariableYaml from './yaml_tests/negative_tests/project_path/include/invalid_variable.yml';
import ProjectPathIncludeLeadSlashYaml from './yaml_tests/negative_tests/project_path/include/leading_slash.yml';
import ProjectPathIncludeNoSlashYaml from './yaml_tests/negative_tests/project_path/include/no_slash.yml';
import ProjectPathIncludeTailSlashYaml from './yaml_tests/negative_tests/project_path/include/tailing_slash.yml';
import RulesNegativeYaml from './yaml_tests/negative_tests/rules.yml';
import RulesNeedsNegativeYaml from './yaml_tests/negative_tests/rules_needs.yml';
import TriggerNegative from './yaml_tests/negative_tests/trigger.yml';
import VariablesInvalidOptionsYaml from './yaml_tests/negative_tests/variables/invalid_options.yml';
import VariablesInvalidSyntaxDescYaml from './yaml_tests/negative_tests/variables/invalid_syntax_desc.yml';
import VariablesWrongSyntaxUsageExpand from './yaml_tests/negative_tests/variables/wrong_syntax_usage_expand.yml';
import IdTokensNegativeYaml from './yaml_tests/negative_tests/id_tokens.yml';
import HooksNegative from './yaml_tests/negative_tests/hooks.yml';
import SecretsNegativeYaml from './yaml_tests/negative_tests/secrets.yml';
import ServicesNegativeYaml from './yaml_tests/negative_tests/services.yml';

const ajv = new Ajv({
  strictTypes: false,
  strictTuples: false,
  allowMatchingProperties: true,
});
ajv.addKeyword('markdownDescription');

AjvFormats(ajv);
const ajvSchema = ajv.compile(CiSchema);

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
      ArtifactsYaml,
      CacheYaml,
      FilterYaml,
      IncludeYaml,
      JobWhenYaml,
      HooksYaml,
      RulesYaml,
      RulesNeedsYaml,
      VariablesYaml,
      ProjectPathYaml,
      IdTokensYaml,
      ServicesYaml,
      SecretsYaml,
    }),
  )('schema validates %s', (_, input) => {
    // We construct a new "JSON" from each main key that is inside a
    // file which allow us to make sure each blob is valid.
    Object.keys(input).forEach((key) => {
      expect({ [key]: input[key] }).toValidateJsonSchema(ajvSchema);
    });
  });
});

describe('negative tests', () => {
  it.each(
    Object.entries({
      // JSON
      DefaultNoAdditionalPropertiesJson,
      JobVariablesMustNotContainObjectsJson,
      InheritDefaultNoAdditionalPropertiesJson,
      ReleaseAssetsLinksJson,
      RetryUnknownWhenJson,

      // YAML
      ArtifactsNegativeYaml,
      CacheKeyNeative,
      HooksNegative,
      IdTokensNegativeYaml,
      IncludeNegativeYaml,
      JobWhenNegativeYaml,
      RulesNegativeYaml,
      RulesNeedsNegativeYaml,
      TriggerNegative,
      VariablesInvalidOptionsYaml,
      VariablesInvalidSyntaxDescYaml,
      VariablesWrongSyntaxUsageExpand,
      ProjectPathIncludeEmptyYaml,
      ProjectPathIncludeInvalidVariableYaml,
      ProjectPathIncludeLeadSlashYaml,
      ProjectPathIncludeNoSlashYaml,
      ProjectPathIncludeTailSlashYaml,
      SecretsNegativeYaml,
      ServicesNegativeYaml,
    }),
  )('schema validates %s', (_, input) => {
    // We construct a new "JSON" from each main key that is inside a
    // file which allow us to make sure each blob is invalid.
    Object.keys(input).forEach((key) => {
      expect({ [key]: input[key] }).not.toValidateJsonSchema(ajvSchema);
    });
  });
});
