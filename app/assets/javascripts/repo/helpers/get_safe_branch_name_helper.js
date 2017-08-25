function getSafeBranchName(text) {
  return text.split(' ').join('-') // replaces space with dash
    .replace(/[^a-zA-Z0-9-/]/g, ''); // replace non alphanumeric
}

export default getSafeBranchName;
