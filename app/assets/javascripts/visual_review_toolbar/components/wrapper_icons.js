import { buttonClearStyles } from './utils';

const commentIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/comment</title><path d="M4 11.132l1.446-.964A1 1 0 0 1 6 10h5a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v6.132zM6.303 12l-2.748 1.832A1 1 0 0 1 2 13V5a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3H6.303z" id="gitlab-comment-icon"/></svg>
`;

const compressIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/compress</title><path d="M5.27 12.182l-1.562 1.561a1 1 0 0 1-1.414 0h-.001a1 1 0 0 1 0-1.415l1.56-1.56L2.44 9.353a.5.5 0 0 1 .353-.854H7.09a.5.5 0 0 1 .5.5v4.294a.5.5 0 0 1-.853.353l-1.467-1.465zm6.911-6.914l1.464 1.464a.5.5 0 0 1-.353.854H8.999a.5.5 0 0 1-.5-.5V2.793a.5.5 0 0 1 .854-.354l1.414 1.415 1.56-1.561a1 1 0 1 1 1.415 1.414l-1.561 1.56z" id="gitlab-compress-icon"/></svg>
`;

const collapseButton = `
  <button id='gitlab-collapse' style='${buttonClearStyles}' class='gitlab-button gitlab-button-secondary gitlab-collapse gitlab-collapse-open'>${compressIcon}</button>
`;

export { commentIcon, compressIcon, collapseButton };
