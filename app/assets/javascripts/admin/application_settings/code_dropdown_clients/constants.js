import { s__, sprintf } from '~/locale';

export const MAX_CLIENTS = 20;
export const NAME_MAX_LENGTH = 50;
export const TEMPLATE_MAX_LENGTH = 500;

export const URL_PLACEHOLDER = '{url}';

// Scheme syntax per RFC 3986 section 3.1.
export const SCHEME_FORMAT = /^[a-z][a-z0-9+.-]*$/i;

// Mirrors ApplicationSetting::CODE_DROPDOWN_BLOCKED_SCHEMES. Admins are deliberately not
// restricted to a fixed list of client schemes; what is refused is the small, fixed set a
// browser can execute or read local files from. Keep both lists in step.
export const BLOCKED_SCHEMES = [
  'javascript',
  'data',
  'vbscript',
  'file',
  'blob',
  'filesystem',
  'about',
];

const schemeOf = (template) => {
  const separator = template.indexOf(':');

  if (separator < 1) return null;

  return template.slice(0, separator);
};

/**
 * Mirrors ApplicationSetting#validate_code_dropdown_entry_name.
 * Returns an error string, or null when the name is acceptable.
 */
export const validateName = (name, { others = [] } = {}) => {
  const trimmed = name.trim();

  if (!trimmed) return s__('CodeDropdownClients|Enter a display name.');

  if (trimmed.length > NAME_MAX_LENGTH) {
    return sprintf(s__('CodeDropdownClients|Display name must be %{max} characters or less.'), {
      max: NAME_MAX_LENGTH,
    });
  }

  if (others.some((entry) => (entry.name || '').trim().toLowerCase() === trimmed.toLowerCase())) {
    return s__('CodeDropdownClients|Another client already uses this display name.');
  }

  return null;
};

/**
 * Mirrors ApplicationSetting#validate_code_dropdown_entry_template and
 * #validate_code_dropdown_template_url. A blank template is valid here; the
 * "at least one template" rule is enforced by validateEntry.
 * Returns an error string, or null when the template is acceptable.
 */
export const validateTemplate = (template, { others = [] } = {}) => {
  const trimmed = template.trim();

  if (!trimmed) return null;

  if (trimmed.length > TEMPLATE_MAX_LENGTH) {
    return sprintf(s__('CodeDropdownClients|URL template must be %{max} characters or less.'), {
      max: TEMPLATE_MAX_LENGTH,
    });
  }

  if (trimmed.split(URL_PLACEHOLDER).length - 1 !== 1) {
    return s__('CodeDropdownClients|URL template must contain {url} exactly once.');
  }

  const scheme = schemeOf(trimmed);

  if (!scheme || !SCHEME_FORMAT.test(scheme)) {
    return s__(
      'CodeDropdownClients|URL template must be a valid URL with a scheme, for example vscode://.',
    );
  }

  if (BLOCKED_SCHEMES.includes(scheme.toLowerCase())) {
    return sprintf(s__('CodeDropdownClients|The %{scheme} scheme is not allowed.'), { scheme });
  }

  // The same template may legitimately be used for both SSH and HTTPS within one entry,
  // so only a *different* entry claiming it is a conflict.
  const claimed = others.some((entry) =>
    [entry.ssh_url_template, entry.http_url_template].some(
      (value) => (value || '').trim().toLowerCase() === trimmed.toLowerCase(),
    ),
  );

  if (claimed) return s__('CodeDropdownClients|Another client already uses this URL template.');

  return null;
};

/**
 * Entry-level rule from the JSON schema's `anyOf`: at least one template is required.
 */
export const validateEntry = ({ sshUrlTemplate, httpUrlTemplate }) =>
  sshUrlTemplate.trim() || httpUrlTemplate.trim()
    ? null
    : s__('CodeDropdownClients|Enter at least one URL template.');
