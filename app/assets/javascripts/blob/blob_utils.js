// capture anything starting with http:// or https://
// up until a disallowed character or whitespace
export const blobLinkRegex = /https?:\/\/[^"<>\\^`{|}\s]+/g;

export default { blobLinkRegex };
