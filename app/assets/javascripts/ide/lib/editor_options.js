export default [{
  readOnly: model => !!model.file.file_lock,
}];
