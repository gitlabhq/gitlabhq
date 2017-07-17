const RepoFileOptions = {
  template: `
    <tr v-if='isMini' class='repo-file-options'>
      <td>
        <span class='title'>{{projectName}}</span>
        <ul>
          <li>
            <a href='#' title='New File'>
              <i class='fa fa-file-o'></i>
            </a>
          </li>
          <li>
            <a href='#' title='New Folder'>
              <i class='fa fa-folder-o'></i>
            </a>
          </li>
        </ul>
      </td>
    </tr>
  `,
  props: {
    name: 'repo-file-options',
    isMini: Boolean,
    projectName: String,
  },
};

export default RepoFileOptions;
