// https://prosemirror.net/docs/ref/#model.ParseRule.priority
export const DEFAULT_PARSE_RULE_PRIORITY = 50;
export const HIGHER_PARSE_RULE_PRIORITY = 1 + DEFAULT_PARSE_RULE_PRIORITY;

export const unrestrictedPages = [
  // Group wiki
  'groups:wikis:show',
  'groups:wikis:edit',
  'groups:wikis:create',

  // Project wiki
  'projects:wikis:show',
  'projects:wikis:edit',
  'projects:wikis:create',

  // Project files
  'projects:show',
  'projects:blob:show',
];
