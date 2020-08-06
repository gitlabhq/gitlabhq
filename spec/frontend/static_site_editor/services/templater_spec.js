/* eslint-disable no-useless-escape */
import templater from '~/static_site_editor/services/templater';

describe('templater', () => {
  const source = `Some text

<% some erb code %>

Some more text

<% if apptype.maturity && (apptype.maturity != "planned") %>
  <% maturity = "This application type is at the \"#{apptype.maturity}\" level of maturity." %>
<% end %>

With even text with indented code above.
`;
  const sourceTemplated = `Some text

\`\`\` sse
<% some erb code %>
\`\`\`

Some more text

\`\`\` sse
<% if apptype.maturity && (apptype.maturity != "planned") %>
  <% maturity = "This application type is at the \"#{apptype.maturity}\" level of maturity." %>
<% end %>
\`\`\`

With even text with indented code above.
`;

  it.each`
    fn          | initial            | target
    ${'wrap'}   | ${source}          | ${sourceTemplated}
    ${'wrap'}   | ${sourceTemplated} | ${sourceTemplated}
    ${'unwrap'} | ${sourceTemplated} | ${source}
    ${'unwrap'} | ${source}          | ${source}
  `(
    'wraps $initial in a templated sse codeblock if $fn is wrap, unwraps otherwise',
    ({ fn, initial, target }) => {
      expect(templater[fn](initial)).toMatch(target);
    },
  );
});
