export const mockIdeItems = [
  {
    extraAttrs: {
      target: '_blank',
    },
    href: 'webIdeUrl://foo.bar',
    shortcut: '.',
    testId: 'webide-menu-item',
    text: 'Web IDE',
    tracking: {
      action: 'click_consolidated_edit',
      label: 'web_ide',
    },
  },
  {
    extraAttrs: {
      target: '_blank',
    },
    href: 'gitpodUrl://foo.bar',
    text: 'GitPod',
    tracking: {
      action: 'click_consolidated_edit',
      label: 'gitpod',
    },
  },
  {
    items: [
      {
        href: 'vscode://vscode.git/clone?url=ssh%3A%2F%2Ffoo.bar',
        text: 'SSH',
      },
      {
        href: 'vscode://vscode.git/clone?url=http%3A%2F%2Ffoo.bar',
        text: 'HTTPS',
      },
    ],
    text: 'Visual Studio Code',
  },
  {
    items: [
      {
        href: 'jetbrains://idea/checkout/git?idea.required.plugins.id=Git4Idea&checkout.repo=ssh%3A%2F%2Ffoo.bar',
        text: 'SSH',
      },
      {
        href: 'jetbrains://idea/checkout/git?idea.required.plugins.id=Git4Idea&checkout.repo=http%3A%2F%2Ffoo.bar',
        text: 'HTTPS',
      },
    ],
    text: 'IntelliJ IDEA',
  },
  {
    href: 'xcode://foo.bar',
    text: 'Xcode',
  },
];

export const expectedSourceCodeItems = [
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.zip',
    text: 'zip',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar.gz',
    text: 'tar.gz',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar.bz2',
    text: 'tar.bz2',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar',
    text: 'tar',
  },
];

export const expectedDirectoryDownloadItems = [
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.zip?path=/subdir',
    text: 'zip',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar.gz?path=/subdir',
    text: 'tar.gz',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar.bz2?path=/subdir',
    text: 'tar.bz2',
  },
  {
    extraAttrs: {
      download: '',
      rel: 'nofollow',
    },
    href: 'http://foo.bar/archive.tar?path=/subdir',
    text: 'tar',
  },
];
