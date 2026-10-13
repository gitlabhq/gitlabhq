import { s__, sprintf } from '~/locale';
import { PROMO_URL } from '~/constants';

const HANDSHAKE = String.fromCodePoint(0x1f91d);
const MAG = String.fromCodePoint(0x1f50e);
const ROCKET = String.fromCodePoint(0x1f680);

// Same Braille tanuki and colors as the Duo CLI:
// https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/tui/src/lib/components/GitLabLogo.tsx
const TANUKI_GLYPH = [
  '⠀⠀⣰⣧⠀⠀⠀⠀⠀⠀⣼⣆⠀⠀',
  '⠀⢠⣿⣿⡆⣀⣀⣀⣀⢰⣿⣿⡄⠀',
  '⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀',
  '⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀',
  '⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀',
  '⠀⠀⠀⠀⠈⠙⢿⡿⠋⠁⠀⠀⠀⠀',
];
const TANUKI_FG = [
  '  ##      ##  ',
  ' ############ ',
  ' +##########+ ',
  ' ++++####++++ ',
  '  ++++..++++  ',
  '    ......    ',
];
// Without an explicit font, macOS falls back to an Apple Braille face that also draws the empty dots.
const TANUKI_FONT = "'Apple Symbols', 'Segoe UI Symbol', 'DejaVu Sans Mono', monospace";
const TANUKI_COLORS = { '#': '#e2432a', '+': '#fc6d27', '.': '#fca326', ' ': 'inherit' };

const tanukiSpans = TANUKI_GLYPH.map((glyph, row) =>
  [...TANUKI_FG[row].matchAll(/(.)\1*/g)].map(({ 0: run, 1: key, index }) => ({
    text: glyph.slice(index, index + run.length),
    style: `color: ${TANUKI_COLORS[key]}; font-weight: bold; font-family: ${TANUKI_FONT}; line-height: 1;`,
  })),
);
const TANUKI = tanukiSpans.map((spans) => spans.map(({ text }) => `%c${text}`).join('')).join('\n');
const TANUKI_STYLES = tanukiSpans.flat().map(({ style }) => style);

export const logHello = () => {
  // eslint-disable-next-line no-console
  console.log(
    `${TANUKI}
%c${s__('HelloMessage|Welcome to GitLab!')}%c

${s__(
  'HelloMessage|Does this page need fixes or improvements? Open an issue or contribute a merge request to help make GitLab more lovable. At GitLab, everyone can contribute!',
)}

${sprintf(s__('HelloMessage|%{handshake_emoji} Contribute to GitLab: %{contribute_link}'), {
  handshake_emoji: `${HANDSHAKE}`,
  contribute_link: `${PROMO_URL}/community/contribute/`,
})}
${sprintf(s__('HelloMessage|%{magnifier_emoji} Create a new GitLab issue: %{new_issue_link}'), {
  magnifier_emoji: `${MAG}`,
  new_issue_link: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/new',
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
    ...TANUKI_STYLES,
    'padding-top: 0.5em; font-size: 2em;',
    'padding-bottom: 0.5em;',
  );
};
