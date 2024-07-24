import { serialize, builders } from '../../serialization_utils';

const { paragraph, details, detailsContent, heading, bold, italic, codeBlock } = builders;

it('correctly renders a simple details/summary', () => {
  expect(
    serialize(
      details(
        detailsContent(paragraph('this is the summary')),
        detailsContent(paragraph('this content will be hidden')),
      ),
      heading('this is a heading'),
    ),
  ).toBe(
    `
<details>
<summary>this is the summary</summary>
this content will be hidden
</details>

# this is a heading
      `.trim(),
  );
});

it('correctly renders details/summary with styled content', () => {
  expect(
    serialize(
      details(
        detailsContent(paragraph('this is the ', bold('summary'))),
        detailsContent(
          codeBlock(
            { language: 'javascript' },
            'var a = 2;\nvar b = 3;\nvar c = a + d;\n\nconsole.log(c);',
          ),
        ),
        detailsContent(paragraph('this content will be ', italic('hidden'))),
      ),
      details(detailsContent(paragraph('summary 2')), detailsContent(paragraph('content 2'))),
    ).trim(),
  ).toBe(
    `
<details>
<summary>

this is the **summary**

</summary>

\`\`\`javascript
var a = 2;
var b = 3;
var c = a + d;

console.log(c);
\`\`\`

this content will be _hidden_

</details>

<details>
<summary>summary 2</summary>
content 2
</details>
      `.trim(),
  );
});

it('correctly renders nested details', () => {
  expect(
    serialize(
      details(
        // if paragraph contains special characters, it should be escaped and rendered as block
        detailsContent(paragraph('dream level 1*')),
        detailsContent(
          details(
            detailsContent(paragraph('dream level 2')),
            detailsContent(
              details(
                detailsContent(paragraph('dream level 3')),
                detailsContent(paragraph(italic('inception'))),
              ),
            ),
          ),
        ),
      ),
    ).trim(),
  ).toBe(
    `
<details>
<summary>

dream level 1\\*
</summary>

<details>
<summary>dream level 2</summary>

<details>
<summary>dream level 3</summary>

_inception_

</details>

</details>

</details>
      `.trim(),
  );
});
