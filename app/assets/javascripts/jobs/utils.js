// capture anything starting with http:// or https://
// up until a disallowed character or whitespace
export const linkRegex = /(https?:\/\/[^"<>\\^`{|}\s]+)/g;
export default { linkRegex };
