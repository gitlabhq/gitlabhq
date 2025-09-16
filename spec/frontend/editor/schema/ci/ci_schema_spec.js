import Ajv from 'ajv';
import AjvFormats from 'ajv-formats';
import CiSchema from '~/editor/schema/ci.json';

// JSON POSITIVE TESTS (LEGACY)
import AllowFailureJson from './json_tests/positive_tests/allow_failure.json';
import EnvironmentJson from './json_tests/positive_tests/environment.json';
import GitlabCiDependenciesJson from './json_tests/positive_tests/gitlab-ci-dependencies.json';
import GitlabCiJson from './json_tests/positive_tests/gitlab-ci.json';
import InheritJson from './json_tests/positive_tests/inherit.json';
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
import ImageYaml from './yaml_tests/positive_tests/image.yml';
import CacheYaml from './yaml_tests/positive_tests/cache.yml';
import CacheFilesCommitsYaml from './yaml_tests/positive_tests/cache_files_commits.yml';
import MultipleCachesYaml from './yaml_tests/positive_tests/cache_multiple.yml';
import FilterYaml from './yaml_tests/positive_tests/filter.yml';
import IncludeYaml from './yaml_tests/positive_tests/include.yml';
import RulesYaml from './yaml_tests/positive_tests/rules.yml';
import RulesNeedsYaml from './yaml_tests/positive_tests/rules_needs.yml';
import RunYaml from './yaml_tests/positive_tests/run.yml';
import ProjectPathYaml from './yaml_tests/positive_tests/project_path.yml';
import SpecInputsYaml from './yaml_tests/positive_tests/spec_inputs.yml';
import VariablesYaml from './yaml_tests/positive_tests/variables.yml';
import JobWhenYaml from './yaml_tests/positive_tests/job_when.yml';
import IdTokensYaml from './yaml_tests/positive_tests/id_tokens.yml';
import HooksYaml from './yaml_tests/positive_tests/hooks.yml';
import SecretsYaml from './yaml_tests/positive_tests/secrets.yml';
import ServicesYaml from './yaml_tests/positive_tests/services.yml';
import NeedsParallelMatrixYaml from './yaml_tests/positive_tests/needs_parallel_matrix.yml';
import ScriptYaml from './yaml_tests/positive_tests/script.yml';
import WorkflowAutoCancelOnJobFailureYaml from './yaml_tests/positive_tests/workflow/auto_cancel/on_job_failure.yml';
import WorkflowAutoCancelOnNewCommitYaml from './yaml_tests/positive_tests/workflow/auto_cancel/on_new_commit.yml';
import WorkflowRulesAutoCancelOnJobFailureYaml from './yaml_tests/positive_tests/workflow/rules/auto_cancel/on_job_failure.yml';
import WorkflowRulesAutoCancelOnNewCommitYaml from './yaml_tests/positive_tests/workflow/rules/auto_cancel/on_new_commit.yml';
import StagesYaml from './yaml_tests/positive_tests/stages.yml';
import RetryYaml from './yaml_tests/positive_tests/retry.yml';
import ParallelYaml from './yaml_tests/positive_tests/parallel.yml';
import TriggerYaml from './yaml_tests/positive_tests/trigger.yml';

// YAML NEGATIVE TEST
import ArtifactsNegativeYaml from './yaml_tests/negative_tests/artifacts.yml';
import ImageNegativeYaml from './yaml_tests/negative_tests/image.yml';
import CacheKeyNeative from './yaml_tests/negative_tests/cache.yml';
import MultipleCachesYamlNegative from './yaml_tests/negative_tests/cache_multiple.yml';
import IncludeNegativeYaml from './yaml_tests/negative_tests/include.yml';
import JobWhenNegativeYaml from './yaml_tests/negative_tests/job_when.yml';
import ProjectPathIncludeEmptyYaml from './yaml_tests/negative_tests/project_path/include/empty.yml';
import ProjectPathIncludeInvalidVariableYaml from './yaml_tests/negative_tests/project_path/include/invalid_variable.yml';
import ProjectPathIncludeLeadSlashYaml from './yaml_tests/negative_tests/project_path/include/leading_slash.yml';
import ProjectPathIncludeNoSlashYaml from './yaml_tests/negative_tests/project_path/include/no_slash.yml';
import ProjectPathIncludeTailSlashYaml from './yaml_tests/negative_tests/project_path/include/tailing_slash.yml';
import RulesNegativeYaml from './yaml_tests/negative_tests/rules.yml';
import RulesNeedsNegativeYaml from './yaml_tests/negative_tests/rules_needs.yml';
import RunNegativeYaml from './yaml_tests/negative_tests/run.yml';
import SpecInputsNegativeYaml from './yaml_tests/negative_tests/spec_inputs.yml';
import TriggerNegativeYaml from './yaml_tests/negative_tests/trigger.yml';
import VariablesInvalidOptionsYaml from './yaml_tests/negative_tests/variables/invalid_options.yml';
import VariablesInvalidSyntaxDescYaml from './yaml_tests/negative_tests/variables/invalid_syntax_desc.yml';
import VariablesWrongSyntaxUsageExpand from './yaml_tests/negative_tests/variables/wrong_syntax_usage_expand.yml';
import IdTokensNegativeYaml from './yaml_tests/negative_tests/id_tokens.yml';
import HooksNegative from './yaml_tests/negative_tests/hooks.yml';
import SecretsNegativeYaml from './yaml_tests/negative_tests/secrets.yml';
import ServicesNegativeYaml from './yaml_tests/negative_tests/services.yml';
import NeedsParallelMatrixNumericYaml from './yaml_tests/negative_tests/needs/parallel_matrix/numeric.yml';
import NeedsParallelMatrixWrongParallelValueYaml from './yaml_tests/negative_tests/needs/parallel_matrix/wrong_parallel_value.yml';
import NeedsParallelMatrixWrongMatrixValueYaml from './yaml_tests/negative_tests/needs/parallel_matrix/wrong_matrix_value.yml';
import ScriptNegativeYaml from './yaml_tests/negative_tests/script.yml';
import WorkflowAutoCancelOnJobFailureNegativeYaml from './yaml_tests/negative_tests/workflow/auto_cancel/on_job_failure.yml';
import WorkflowAutoCancelOnNewCommitNegativeYaml from './yaml_tests/negative_tests/workflow/auto_cancel/on_new_commit.yml';
import WorkflowRulesAutoCancelOnJobFailureNegativeYaml from './yaml_tests/negative_tests/workflow/rules/auto_cancel/on_job_failure.yml';
import WorkflowRulesAutoCancelOnNewCommitNegativeYaml from './yaml_tests/negative_tests/workflow/rules/auto_cancel/on_new_commit.yml';
import StagesNegativeYaml from './yaml_tests/negative_tests/stages.yml';
import RetryNegativeYaml from './yaml_tests/negative_tests/retry.yml';
import ParallelNegativeYaml from './yaml_tests/negative_tests/parallel.yml';

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
      RetryJson,
      TerraformReportJson,
      VariablesMixStringAndUserInputJson,
      VariablesJson,

      // YAML
      ArtifactsYaml,
      ImageYaml,
      CacheYaml,
      CacheFilesCommitsYaml,
      MultipleCachesYaml,
      FilterYaml,
      HooksYaml,
      IdTokensYaml,
      IncludeYaml,
      JobWhenYaml,
      NeedsParallelMatrixYaml,
      ParallelYaml,
      ProjectPathYaml,
      RetryYaml,
      RulesYaml,
      RulesNeedsYaml,
      RunYaml,
      ScriptYaml,
      SecretsYaml,
      ServicesYaml,
      SpecInputsYaml,
      StagesYaml,
      TriggerYaml,
      VariablesYaml,
      WorkflowRulesAutoCancelOnJobFailureYaml,
      WorkflowRulesAutoCancelOnNewCommitYaml,
    }),
  )('schema validates %s', (_, input) => {
    // We construct a new "JSON" from each main key that is inside a
    // file which allows us to make sure each blob is valid.
    // Note that this treats each main key as a job or global definition,
    // which means that more than one global definition (e.g. `workflow`)
    // is not allowed. To use multiple global keys on a single test file
    // use the `global positive tests` below.
    Object.keys(input).forEach((key) => {
      expect({ [key]: input[key] }).toValidateJsonSchema(ajvSchema);
    });
  });
});

describe('global positive tests', () => {
  const tests = {
    WorkflowAutoCancelOnJobFailureYaml,
    WorkflowAutoCancelOnNewCommitYaml,
  };
  for (const testName in tests) {
    if (Object.hasOwn(tests, testName)) {
      const test = tests[testName];
      describe(testName, () => {
        // We construct a new "JSON" from each main key that is inside a
        // file which allows us to make sure each blob is valid.
        it.each(Object.entries(test))('schema validates %s', (_, input) => {
          expect(input).toValidateJsonSchema(ajvSchema);
        });
      });
    }
  }
});

describe('negative tests', () => {
  it.each(
    Object.entries({
      // JSON
      DefaultNoAdditionalPropertiesJson,
      InheritDefaultNoAdditionalPropertiesJson,
      JobVariablesMustNotContainObjectsJson,
      ReleaseAssetsLinksJson,
      RetryUnknownWhenJson,

      // YAML
      ArtifactsNegativeYaml,
      CacheKeyNeative,
      HooksNegative,
      IdTokensNegativeYaml,
      ImageNegativeYaml,
      IncludeNegativeYaml,
      JobWhenNegativeYaml,
      MultipleCachesYamlNegative,
      NeedsParallelMatrixNumericYaml,
      NeedsParallelMatrixWrongMatrixValueYaml,
      NeedsParallelMatrixWrongParallelValueYaml,
      ParallelNegativeYaml,
      ProjectPathIncludeEmptyYaml,
      ProjectPathIncludeInvalidVariableYaml,
      ProjectPathIncludeLeadSlashYaml,
      ProjectPathIncludeNoSlashYaml,
      ProjectPathIncludeTailSlashYaml,
      RetryNegativeYaml,
      RulesNeedsNegativeYaml,
      RulesNegativeYaml,
      RunNegativeYaml,
      ScriptNegativeYaml,
      SecretsNegativeYaml,
      ServicesNegativeYaml,
      SpecInputsNegativeYaml,
      StagesNegativeYaml,
      TriggerNegativeYaml,
      VariablesInvalidOptionsYaml,
      VariablesInvalidSyntaxDescYaml,
      VariablesWrongSyntaxUsageExpand,
      WorkflowRulesAutoCancelOnJobFailureNegativeYaml,
      WorkflowRulesAutoCancelOnNewCommitNegativeYaml,
    }),
  )('schema validates %s', (_, input) => {
    // We construct a new "JSON" from each main key that is inside a
    // file which allows us to make sure each blob is invalid.
    // Note that this treats each main key as a job or global definition,
    // which means that using more than one global definition (e.g. `workflow`)
    // on a single test file could lead to incorrect test results.
    // To use multiple global keys on a single test file use the
    // `global negative tests` below.
    Object.keys(input).forEach((key) => {
      expect({ [key]: input[key] }).not.toValidateJsonSchema(ajvSchema);
    });
  });
});

describe('global negative tests', () => {
  const tests = {
    WorkflowAutoCancelOnJobFailureNegativeYaml,
    WorkflowAutoCancelOnNewCommitNegativeYaml,
  };
  for (const testName in tests) {
    if (Object.hasOwn(tests, testName)) {
      const test = tests[testName];
      describe(testName, () => {
        // We construct a new "JSON" from each main key that is inside a
        // file which allows us to make sure each blob is invalid.
        it.each(Object.entries(test))('schema validates %s', (_, input) => {
          expect(input).not.toValidateJsonSchema(ajvSchema);
        });
      });
    }
  }
});
