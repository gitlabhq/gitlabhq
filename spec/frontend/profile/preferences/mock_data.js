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

export const themes = [
  { id: 1, css_class: 'foo' },
  { id: 2, css_class: 'bar' },
  { id: 3, css_class: 'gl-dark' },
];

export const lightModeThemeId1 = 1;

export const lightModeThemeId2 = 2;

export const darkModeThemeId = 3;
