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
import ReleaseAssetsLinksEmptyJson from './json_tests/negative_tests/release_assets_links_empty.json';
import ReleaseAssetsLinksInvalidLinkTypeJson from './json_tests/negative_tests/release_assets_links_invalid_link_type.json';
import ReleaseAssetsLinksMissingJson from './json_tests/negative_tests/release_assets_links_missing.json';
import RetryUnknownWhenJson from './json_tests/negative_tests/retry_unknown_when.json';

// YAML POSITIVE TEST
import ArtifactsYaml from './yaml_tests/positive_tests/artifacts.yml';
import CacheYaml from './yaml_tests/positive_tests/cache.yml';
import FilterYaml from './yaml_tests/positive_tests/filter.yml';
import IncludeYaml from './yaml_tests/positive_tests/include.yml';
import RulesYaml from './yaml_tests/positive_tests/rules.yml';
import ProjectPathYaml from './yaml_tests/positive_tests/project_path.yml';
import VariablesYaml from './yaml_tests/positive_tests/variables.yml';
import JobWhenYaml from './yaml_tests/positive_tests/job_when.yml';

// YAML NEGATIVE TEST
import ArtifactsNegativeYaml from './yaml_tests/negative_tests/artifacts.yml';
import IncludeNegativeYaml from './yaml_tests/negative_tests/include.yml';
import RulesNegativeYaml from './yaml_tests/negative_tests/rules.yml';
import VariablesInvalidSyntaxDescYaml from './yaml_tests/negative_tests/variables/invalid_syntax_desc.yml';
import VariablesWrongSyntaxUsageExpand from './yaml_tests/negative_tests/variables/wrong_syntax_usage_expand.yml';
import JobWhenNegativeYaml from './yaml_tests/negative_tests/job_when.yml';

import ProjectPathIncludeEmptyYaml from './yaml_tests/negative_tests/project_path/include/empty.yml';
import ProjectPathIncludeInvalidVariableYaml from './yaml_tests/negative_tests/project_path/include/invalid_variable.yml';
import ProjectPathIncludeLeadSlashYaml from './yaml_tests/negative_tests/project_path/include/leading_slash.yml';
import ProjectPathIncludeNoSlashYaml from './yaml_tests/negative_tests/project_path/include/no_slash.yml';
import ProjectPathIncludeTailSlashYaml from './yaml_tests/negative_tests/project_path/include/tailing_slash.yml';
import ProjectPathTriggerIncludeEmptyYaml from './yaml_tests/negative_tests/project_path/trigger/include/empty.yml';
import ProjectPathTriggerIncludeInvalidVariableYaml from './yaml_tests/negative_tests/project_path/trigger/include/invalid_variable.yml';
import ProjectPathTriggerIncludeLeadSlashYaml from './yaml_tests/negative_tests/project_path/trigger/include/leading_slash.yml';
import ProjectPathTriggerIncludeNoSlashYaml from './yaml_tests/negative_tests/project_path/trigger/include/no_slash.yml';
import ProjectPathTriggerIncludeTailSlashYaml from './yaml_tests/negative_tests/project_path/trigger/include/tailing_slash.yml';
import ProjectPathTriggerMinimalEmptyYaml from './yaml_tests/negative_tests/project_path/trigger/minimal/empty.yml';
import ProjectPathTriggerMinimalInvalidVariableYaml from './yaml_tests/negative_tests/project_path/trigger/minimal/invalid_variable.yml';
import ProjectPathTriggerMinimalLeadSlashYaml from './yaml_tests/negative_tests/project_path/trigger/minimal/leading_slash.yml';
import ProjectPathTriggerMinimalNoSlashYaml from './yaml_tests/negative_tests/project_path/trigger/minimal/no_slash.yml';
import ProjectPathTriggerMinimalTailSlashYaml from './yaml_tests/negative_tests/project_path/trigger/minimal/tailing_slash.yml';
import ProjectPathTriggerProjectEmptyYaml from './yaml_tests/negative_tests/project_path/trigger/project/empty.yml';
import ProjectPathTriggerProjectInvalidVariableYaml from './yaml_tests/negative_tests/project_path/trigger/project/invalid_variable.yml';
import ProjectPathTriggerProjectLeadSlashYaml from './yaml_tests/negative_tests/project_path/trigger/project/leading_slash.yml';
import ProjectPathTriggerProjectNoSlashYaml from './yaml_tests/negative_tests/project_path/trigger/project/no_slash.yml';
import ProjectPathTriggerProjectTailSlashYaml from './yaml_tests/negative_tests/project_path/trigger/project/tailing_slash.yml';

import CacheKeyFilesNotArray from './yaml_tests/negative_tests/cache/key_files_not_an_array.yml';
import CacheKeyPrefixArray from './yaml_tests/negative_tests/cache/key_prefix_array.yml';
import CacheKeyWithDot from './yaml_tests/negative_tests/cache/key_with_dot.yml';
import CacheKeyWithMultipleDots from './yaml_tests/negative_tests/cache/key_with_multiple_dots.yml';
import CacheKeyWithSlash from './yaml_tests/negative_tests/cache/key_with_slash.yml';
import CachePathsNotAnArray from './yaml_tests/negative_tests/cache/paths_not_an_array.yml';
import CacheUntrackedString from './yaml_tests/negative_tests/cache/untracked_string.yml';
import CacheWhenInteger from './yaml_tests/negative_tests/cache/when_integer.yml';
import CacheWhenNotReservedKeyword from './yaml_tests/negative_tests/cache/when_not_reserved_keyword.yml';

const ajv = new Ajv({
  strictTypes: false,
  strictTuples: false,
  allowMatchingProperties: true,
});
ajv.addKeyword('markdownDescription');

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
      ArtifactsYaml,
      CacheYaml,
      FilterYaml,
      IncludeYaml,
      JobWhenYaml,
      RulesYaml,
      VariablesYaml,
      ProjectPathYaml,
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
      ArtifactsNegativeYaml,
      CacheKeyFilesNotArray,
      CacheKeyPrefixArray,
      CacheKeyWithDot,
      CacheKeyWithMultipleDots,
      CacheKeyWithSlash,
      CachePathsNotAnArray,
      CacheUntrackedString,
      CacheWhenInteger,
      CacheWhenNotReservedKeyword,
      IncludeNegativeYaml,
      JobWhenNegativeYaml,
      RulesNegativeYaml,
      VariablesInvalidSyntaxDescYaml,
      VariablesWrongSyntaxUsageExpand,
      ProjectPathIncludeEmptyYaml,
      ProjectPathIncludeInvalidVariableYaml,
      ProjectPathIncludeLeadSlashYaml,
      ProjectPathIncludeNoSlashYaml,
      ProjectPathIncludeTailSlashYaml,
      ProjectPathTriggerIncludeEmptyYaml,
      ProjectPathTriggerIncludeInvalidVariableYaml,
      ProjectPathTriggerIncludeLeadSlashYaml,
      ProjectPathTriggerIncludeNoSlashYaml,
      ProjectPathTriggerIncludeTailSlashYaml,
      ProjectPathTriggerMinimalEmptyYaml,
      ProjectPathTriggerMinimalInvalidVariableYaml,
      ProjectPathTriggerMinimalLeadSlashYaml,
      ProjectPathTriggerMinimalNoSlashYaml,
      ProjectPathTriggerMinimalTailSlashYaml,
      ProjectPathTriggerProjectEmptyYaml,
      ProjectPathTriggerProjectInvalidVariableYaml,
      ProjectPathTriggerProjectLeadSlashYaml,
      ProjectPathTriggerProjectNoSlashYaml,
      ProjectPathTriggerProjectTailSlashYaml,
    }),
  )('schema validates %s', (_, input) => {
    expect(input).not.toValidateJsonSchema(schema);
  });
});
