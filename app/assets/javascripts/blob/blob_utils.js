// capture anything starting with http:// or https:// which is not already part of a html link
// up until a disallowed character or whitespace
export const blobLinkRegex = /(?<!<a href=")https?:\/\/[^"<>\\^`{|}\s]+/g;

export default { blobLinkRegex };
