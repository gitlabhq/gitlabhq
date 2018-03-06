import initPathLocks from '../../../path_locks';

export default () => {
  const dataEl = document.getElementById('js-file-lock');

  if (dataEl) {
    const {
      toggle_path,
      path,
     } = JSON.parse(dataEl.innerHTML);

    initPathLocks(toggle_path, path);
  }
};
