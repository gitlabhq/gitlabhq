export const conflictsMock = {
  target_branch: 'main',
  source_branch: 'test-conflicts',
  source_commit: {
    sha: '4fcf0elettucr3x7im9qid',
    message: 'File added',
  },
  commit_sha: '6dbf385a3c7bf01e09b5d2d9e5d72f8fb8c590a3',
  commit_message:
    "Merge branch 'main' into 'test-conflicts'\n\n# Conflicts:\n#   .gitlab-ci.yml\n#   README.md",
  files: [
    {
      old_path: '.gitlab-ci.yml',
      new_path: '.gitlab-ci.yml',
      blob_icon: 'doc-text',
      blob_path:
        '/gitlab-org/gitlab-test/-/blob/6dbf385a3c7bf01e09b5d2d9e5d72f8fb8c590a3/.gitlab-ci.yml',
      sections: [
        {
          conflict: false,
          lines: [
            {
              line_code: null,
              type: 'match',
              old_line: null,
              new_line: null,
              text: '@@ -7,10 +7,11 @@ upload:',
              meta_data: { old_pos: 7, new_pos: 7 },
              rich_text: '@@ -7,10 +7,11 @@ upload:',
              can_receive_suggestion: true,
            },
            {
              line_code: '587d266bb27a4dc3022bbed44dfa19849df3044c_7_7',
              type: null,
              old_line: 7,
              new_line: 7,
              text: '  stage: upload',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC7" class="line" lang="yaml"\u003e  \u003cspan class="na"\u003estage\u003c/span\u003e\u003cspan class="pi"\u003e:\u003c/span\u003e \u003cspan class="s"\u003eupload\u003c/span\u003e\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '587d266bb27a4dc3022bbed44dfa19849df3044c_8_8',
              type: null,
              old_line: 8,
              new_line: 8,
              text: '  script:',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC8" class="line" lang="yaml"\u003e  \u003cspan class="na"\u003escript\u003c/span\u003e\u003cspan class="pi"\u003e:\u003c/span\u003e\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '587d266bb27a4dc3022bbed44dfa19849df3044c_9_9',
              type: null,
              old_line: 9,
              new_line: 9,
              text:
                // eslint-disable-next-line no-template-curly-in-string
                '    - \'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file README.md ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/0.0.1/file.txt\'',
              meta_data: null,
              rich_text:
                // eslint-disable-next-line no-template-curly-in-string
                '\u003cspan id="LC9" class="line" lang="yaml"\u003e    \u003cspan class="pi"\u003e-\u003c/span\u003e \u003cspan class="s1"\u003e\'\u003c/span\u003e\u003cspan class="s"\u003ecurl\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003e--header\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003e"JOB-TOKEN:\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003e$CI_JOB_TOKEN"\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003e--upload-file\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003eREADME.md\u003c/span\u003e\u003cspan class="nv"\u003e \u003c/span\u003e\u003cspan class="s"\u003e${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/0.0.1/file.txt\'\u003c/span\u003e\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
          ],
        },
        {
          conflict: true,
          lines: [
            {
              line_code: '587d266bb27a4dc3022bbed44dfa19849df3044c_10_10',
              type: 'new',
              old_line: null,
              new_line: 10,
              text: '# some new comments',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC10" class="line" lang="yaml"\u003e\u003cspan class="c1"\u003e# some new comments\u003c/span\u003e\u003c/span\u003e',
              can_receive_suggestion: true,
            },
            {
              line_code: '587d266bb27a4dc3022bbed44dfa19849df3044c_10_11',
              type: 'old',
              old_line: 10,
              new_line: null,
              text: '# a different comment',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC10" class="line" lang="yaml"\u003e\u003cspan class="c1"\u003e# a different comment\u003c/span\u003e\u003c/span\u003e',
              can_receive_suggestion: false,
            },
          ],
          id: '587d266bb27a4dc3022bbed44dfa19849df3044c_10_10',
        },
      ],
      type: 'text',
      content_path:
        '/gitlab-org/gitlab-test/-/merge_requests/2/conflict_for_path?new_path=.gitlab-ci.yml\u0026old_path=.gitlab-ci.yml',
    },
    {
      old_path: 'README.md',
      new_path: 'README.md',
      blob_icon: 'doc-text',
      blob_path:
        '/gitlab-org/gitlab-test/-/blob/6dbf385a3c7bf01e09b5d2d9e5d72f8fb8c590a3/README.md',
      sections: [
        {
          conflict: false,
          lines: [
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_1_1',
              type: null,
              old_line: 1,
              new_line: 1,
              text: '- 1',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC1" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 1\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_2_2',
              type: null,
              old_line: 2,
              new_line: 2,
              text: '- 2',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC2" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 2\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_3_3',
              type: null,
              old_line: 3,
              new_line: 3,
              text: '- 3',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC3" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 3\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
          ],
        },
        {
          conflict: true,
          lines: [
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_4_4',
              type: 'new',
              old_line: null,
              new_line: 4,
              text: '- 4c',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC4" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 4c\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_4_5',
              type: 'old',
              old_line: 4,
              new_line: null,
              text: '- 4b',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC4" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 4b\u003c/span\u003e\n',
              can_receive_suggestion: false,
            },
          ],
          id: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_4_4',
        },
        {
          conflict: false,
          lines: [
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_5_5',
              type: null,
              old_line: 5,
              new_line: 5,
              text: '- 5',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC5" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 5\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_6_6',
              type: null,
              old_line: 6,
              new_line: 6,
              text: '- 6',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC6" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 6\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_7_7',
              type: null,
              old_line: 7,
              new_line: 7,
              text: '- 7',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC7" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 7\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
          ],
        },
        {
          conflict: false,
          lines: [
            {
              line_code: null,
              type: 'match',
              old_line: null,
              new_line: null,
              text: '@@ -9,15 +9,15 @@',
              meta_data: { old_pos: 9, new_pos: 9 },
              rich_text: '@@ -9,15 +9,15 @@',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_9_9',
              type: null,
              old_line: 9,
              new_line: 9,
              text: '- 9',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC9" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 9\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_10_10',
              type: null,
              old_line: 10,
              new_line: 10,
              text: '- 10',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC10" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 10\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_11_11',
              type: null,
              old_line: 11,
              new_line: 11,
              text: '- 11',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC11" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 11\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
          ],
        },
        {
          conflict: true,
          lines: [
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_12_12',
              type: 'new',
              old_line: null,
              new_line: 12,
              text: '- 12c',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC12" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 12c\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_12_13',
              type: 'old',
              old_line: 12,
              new_line: null,
              text: '- 12b',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC12" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 12b\u003c/span\u003e\n',
              can_receive_suggestion: false,
            },
          ],
          id: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_12_12',
        },
        {
          conflict: false,
          lines: [
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_13_13',
              type: null,
              old_line: 13,
              new_line: 13,
              text: '- 13',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC13" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 13\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_14_14',
              type: null,
              old_line: 14,
              new_line: 14,
              text: '- 14 ',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC14" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 14 \u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: '8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_15_15',
              type: null,
              old_line: 15,
              new_line: 15,
              text: '- 15',
              meta_data: null,
              rich_text:
                '\u003cspan id="LC15" class="line" lang="markdown"\u003e\u003cspan class="p"\u003e-\u003c/span\u003e 15\u003c/span\u003e\n',
              can_receive_suggestion: true,
            },
            {
              line_code: null,
              type: 'match',
              old_line: null,
              new_line: null,
              text: '',
              meta_data: { old_pos: 15, new_pos: 15 },
              rich_text: '',
              can_receive_suggestion: true,
            },
          ],
        },
      ],
      type: 'text',
      content_path:
        '/gitlab-org/gitlab-test/-/merge_requests/2/conflict_for_path?new_path=README.md\u0026old_path=README.md',
    },
  ],
};
