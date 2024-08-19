import { s__, sprintf } from '~/locale';
import { PROMO_URL } from '~/constants';

const HANDSHAKE = String.fromCodePoint(0x1f91d);
const MAG = String.fromCodePoint(0x1f50e);
const ROCKET = String.fromCodePoint(0x1f680);

export const logHello = () => {
  // eslint-disable-next-line no-console
  console.log(
    `%c${s__('HelloMessage|Welcome to GitLab!')}%c

${s__(
  'HelloMessage|Does this page need fixes or improvements? Open an issue or contribute a merge request to help make GitLab more lovable. At GitLab, everyone can contribute!',
)}

${sprintf(s__('HelloMessage|%{handshake_emoji} Contribute to GitLab: %{contribute_link}'), {
  handshake_emoji: `${HANDSHAKE}`,
  contribute_link: `${PROMO_URL}/community/contribute/`,
})}
${sprintf(s__('HelloMessage|%{magnifier_emoji} Create a new GitLab issue: %{new_issue_link}'), {
  magnifier_emoji: `${MAG}`,
  new_issue_link: 'https://gitlab.com/gitlab-org/gitlab/-/issues/new',
})}
${
  window.gon?.dot_com
    ? `${sprintf(
        s__(
          'HelloMessage|%{rocket_emoji} We like your curiosity! Help us improve GitLab by joining the team: %{jobs_page_link}',
        ),
        { rocket_emoji: `${ROCKET}`, jobs_page_link: `${PROMO_URL}/jobs/` },
      )}`
    : ''
}`,
    `padding-top: 0.5em; font-size: 2em;`,
    'padding-bottom: 0.5em;',
  );
};
