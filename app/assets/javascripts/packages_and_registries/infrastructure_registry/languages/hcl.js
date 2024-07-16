/*
Language: Terraform (HCL)
Requires: hcl
Description: Components of Terraform module, copied from 
https://github.com/highlightjs/highlightjs-terraform/blob/eb1b9661e143a43dff6b58b391128ce5cdad31d4/terraform.js
*/

export default (hljs) => {
  const NUMBERS = {
    className: 'number',
    begin: '\\b\\d+(\\.\\d+)?',
    relevance: 0,
  };
  const STRINGS = {
    className: 'string',
    begin: '"',
    end: '"',
    contains: [
      {
        className: 'variable',
        begin: '\\${',
        end: '\\}',
        relevance: 9,
        contains: [
          {
            className: 'string',
            begin: '"',
            end: '"',
          },
          {
            className: 'meta',
            begin: '[A-Za-z_0-9]*\\(',
            end: '\\)',
            contains: [
              NUMBERS,
              {
                className: 'string',
                begin: '"',
                end: '"',
                contains: [
                  {
                    className: 'variable',
                    begin: '\\${',
                    end: '\\}',
                    contains: [
                      {
                        className: 'string',
                        begin: '"',
                        end: '"',
                        contains: [
                          {
                            className: 'variable',
                            begin: '\\${',
                            end: '\\}',
                          },
                        ],
                      },
                      {
                        className: 'meta',
                        begin: '[A-Za-z_0-9]*\\(',
                        end: '\\)',
                      },
                    ],
                  },
                ],
              },
              'self',
            ],
          },
        ],
      },
    ],
  };

  return {
    aliases: ['tf', 'hcl'],
    /* eslint-disable @gitlab/require-i18n-strings */
    keywords: 'resource variable provider output locals module data terraform|10',
    literal: 'false true null',
    /* eslint-enable @gitlab/require-i18n-strings */
    contains: [hljs.COMMENT('\\#', '$'), NUMBERS, STRINGS],
  };
};
