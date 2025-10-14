/**
 * Prepares form data for blob editing operations by appending required fields
 * and converting FormData to a plain object to handle potential line ending mutations.
 *
 * Object.fromEntries is used here to handle potential line ending mutations in FormData.
 * FormData uses the "multipart/form-data" format (RFC 2388), which follows MIME data
 * stream rules (RFC 2046). These specifications require line breaks to be represented
 * as CRLF sequences in the canonical form.
 * See https://stackoverflow.com/questions/69835705/formdata-textarea-puts-r-carriage-return-when-sent-with-post for more details.
 *
 * @param {FormData} formData - The original form data
 * @param {Object} params - Parameters object
 * @param {string} params.fileContent - The file content to be committed
 * @param {string} params.filePath - The path of the file being edited
 * @param {string} params.lastCommitSha - The SHA of the last commit
 * @param {string} params.fromMergeRequestIid - The merge request IID if editing from an MR
 * @returns {Object} Plain object with form data entries
 */
export const prepareEditFormData = (
  formData,
  { fileContent, filePath, lastCommitSha, fromMergeRequestIid },
) => {
  formData.append('file', fileContent);
  formData.append('file_path', filePath);
  formData.append('last_commit_sha', lastCommitSha);
  formData.append('from_merge_request_iid', fromMergeRequestIid);

  return Object.fromEntries(formData);
};

/**
 * Prepares form data for creating new blobs by appending file name and content.
 *
 * Object.fromEntries is used here to handle potential line ending mutations in FormData.
 * FormData uses the "multipart/form-data" format (RFC 2388), which follows MIME data
 * stream rules (RFC 2046). These specifications require line breaks to be represented
 * as CRLF sequences in the canonical form.
 * See https://stackoverflow.com/questions/69835705/formdata-textarea-puts-r-carriage-return-when-sent-with-post for more details.
 *
 * @param {FormData} formData - The original form data
 * @param {Object} params - Parameters object
 * @param {string} params.filePath - The path/name of the new file
 * @param {string} params.fileContent - The content of the new file
 * @returns {Object} Plain object with form data entries
 */
export const prepareCreateFormData = (formData, { filePath, fileContent }) => {
  formData.append('file_name', filePath);
  formData.append('content', fileContent);

  return Object.fromEntries(formData);
};
