const HANDSHAKE = String.fromCodePoint(0x1f91d);
const MAG = String.fromCodePoint(0x1f50e);

export const logHello = () => {
  // eslint-disable-next-line no-console
  console.log(
    `%cWelcome to GitLab!%c

Does this page need fixes or improvements? Open an issue or contribute a merge request to help make GitLab more lovable. At GitLab, everyone can contribute!

${HANDSHAKE} Contribute to GitLab: https://about.gitlab.com/community/contribute/
${MAG} Create a new GitLab issue: https://gitlab.com/gitlab-org/gitlab/-/issues/new`,
    `padding-top: 0.5em; font-size: 2em;`,
    'padding-bottom: 0.5em;',
  );
};
