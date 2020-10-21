/* eslint-disable no-useless-escape */
import templater from '~/static_site_editor/services/templater';

describe('templater', () => {
  const source = `Below this line is a simple ERB (single-line erb block) example.

<% some erb code %>

Below this line is a complex ERB (multi-line erb block) example.

<% if apptype.maturity && (apptype.maturity != "planned") %>
  <% maturity = "This application type is at the \"#{apptype.maturity}\" level of maturity." %>
<% end %>

Below this line is a non-erb (single-line HTML) markup example that also has erb.

<a href="<%= compensation_roadmap.role_path %>"><%= compensation_roadmap.role_path %></a>

Below this line is a non-erb (multi-line HTML block) markup example that also has erb.

<ul>
<% compensation_roadmap.recommendation.recommendations.each do |recommendation| %>
  <li><%= recommendation %></li>
<% end %>
</ul>

Below this line is a block of HTML.

<div>
  <h1>Heading</h1>
  <p>Some paragraph...</p>
</div>

Below this line is a codeblock of the same HTML that should be ignored and preserved.

\`\`\` html
<div>
  <h1>Heading</h1>
  <p>Some paragraph...</p>
</div>
\`\`\`

Below this line is a iframe that should be ignored and preserved

<iframe></iframe>
`;
  const sourceTemplated = `Below this line is a simple ERB (single-line erb block) example.

\`\`\` sse
<% some erb code %>
\`\`\`

Below this line is a complex ERB (multi-line erb block) example.

\`\`\` sse
<% if apptype.maturity && (apptype.maturity != "planned") %>
  <% maturity = "This application type is at the \"#{apptype.maturity}\" level of maturity." %>
<% end %>
\`\`\`

Below this line is a non-erb (single-line HTML) markup example that also has erb.

\`\`\` sse
<a href="<%= compensation_roadmap.role_path %>"><%= compensation_roadmap.role_path %></a>
\`\`\`

Below this line is a non-erb (multi-line HTML block) markup example that also has erb.

\`\`\` sse
<ul>
<% compensation_roadmap.recommendation.recommendations.each do |recommendation| %>
  <li><%= recommendation %></li>
<% end %>
</ul>
\`\`\`

Below this line is a block of HTML.

\`\`\` sse
<div>
  <h1>Heading</h1>
  <p>Some paragraph...</p>
</div>
\`\`\`

Below this line is a codeblock of the same HTML that should be ignored and preserved.

\`\`\` html
<div>
  <h1>Heading</h1>
  <p>Some paragraph...</p>
</div>
\`\`\`

Below this line is a iframe that should be ignored and preserved

<iframe></iframe>
`;

  it.each`
    fn          | initial            | target
    ${'wrap'}   | ${source}          | ${sourceTemplated}
    ${'wrap'}   | ${sourceTemplated} | ${sourceTemplated}
    ${'unwrap'} | ${sourceTemplated} | ${source}
    ${'unwrap'} | ${source}          | ${source}
  `(
    'wraps $initial in a templated sse codeblocks if $fn is wrap, unwraps otherwise',
    ({ fn, initial, target }) => {
      expect(templater[fn](initial)).toMatch(target);
    },
  );
});
