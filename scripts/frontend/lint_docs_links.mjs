#!/usr/bin/env node

import { ESLint } from 'eslint';

const RULE_REQUIRE_VALID_HELP_PAGE_PATH = 'local-rules/require-valid-help-page-path';
const RULE_VUE_REQUIRE_VALID_HELP_PAGE_LINK_COMPONENT =
  'local-rules/vue-require-valid-help-page-link-component';
const RULES = [RULE_REQUIRE_VALID_HELP_PAGE_PATH, RULE_VUE_REQUIRE_VALID_HELP_PAGE_LINK_COMPONENT];

function createESLintInstance(overrideConfig) {
  return new ESLint({ useEslintrc: false, overrideConfig, fix: false });
}

function lint(eslint, filePaths) {
  return eslint.lintFiles(filePaths);
}

function outputLintingResults(results) {
  const outdatedLinksErrors = results.reduce((acc, result) => {
    const errors = result.messages.filter((message) => RULES.includes(message.ruleId));
    if (errors.length) {
      acc.push({
        ...result,
        messages: errors,
        errorCount: errors.length,
        suppressedMessages: [],
        fatalErrorCount: 0,
        warningCount: 0,
        fixableErrorCount: 0,
        fixableWarningCount: 0,
      });
    }
    return acc;
  }, []);
  return outdatedLinksErrors;
}

async function lintFiles(filePaths) {
  console.log(
    `Running ESLint with the following rules enabled:${RULES.map((rule) => `\n* ${rule}`).join('')}`,
  );
  const overrideConfig = {
    env: {
      browser: true,
      es2020: true,
    },
    parserOptions: {
      parser: 'espree',
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
    extends: ['plugin:vue/recommended'],
    plugins: ['local-rules'],
    rules: {
      [RULE_REQUIRE_VALID_HELP_PAGE_PATH]: 'error',
      [RULE_VUE_REQUIRE_VALID_HELP_PAGE_LINK_COMPONENT]: 'error',
    },
  };

  const eslint = createESLintInstance(overrideConfig);
  const results = await lint(eslint, filePaths);
  const formatter = await eslint.loadFormatter();
  const errors = outputLintingResults(results);

  if (errors.length > 0) {
    console.log(formatter.format(errors));
    process.exitCode = 1;
  } else {
    console.log('No issues found!');
  }
}

lintFiles(['./{,ee/}app/assets/javascripts/**/*{.js,.vue}']);
