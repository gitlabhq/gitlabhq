export const integrationViews = [
  {
    name: 'sourcegraph',
    help_link: 'http://foo.com/help',
    message: 'Click %{linkStart}Foo%{linkEnd}!',
    message_url: 'http://foo.com',
  },
  {
    name: 'gitpod',
    help_link: 'http://bar.com/help',
    message: 'Click %{linkStart}Bar%{linkEnd}!',
    message_url: 'http://bar.com',
  },
];

export const userFields = {
  foo_enabled: true,
};

export const bodyClasses = 'ui-light-indigo ui-light gl-dark';

export const lightColorModeId = 1;
export const darkColorModeId = 2;
export const autoColorModeId = 3;

export const colorModes = [
  { id: lightColorModeId, css_class: 'gl-light' },
  { id: darkColorModeId, css_class: 'gl-dark' },
  { id: autoColorModeId, css_class: 'gl-system' },
];

export const themes = [
  { id: 1, css_class: 'foo' },
  { id: 2, css_class: 'bar' },
];

export const themeId1 = 1;

export const themeId2 = 2;
